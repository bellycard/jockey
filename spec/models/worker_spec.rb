require 'spec_helper'

describe Worker do
  describe 'validation' do
    it 'validates scale is greater than or equal to 0' do
      worker = FactoryGirl.create(:worker)
      worker.scale = -1
      expect(worker).to_not be_valid
    end
  end

  describe 'after_commit' do
    it 'reconciles if the scale has changed' do
      worker = FactoryGirl.create(:worker, scale: 1)
      expect(worker).to receive(:reconcile!)
      worker.update_attributes scale: 2
    end

    it 'does not reconcile if the scale did not change' do
      worker = FactoryGirl.create(:worker, scale: 1)
      expect(worker).to_not receive(:reconcile)
      worker.update_attributes name: 'foo', scale: 1
    end
  end

  describe '#restart!' do
    before do
      @worker = FactoryGirl.create(:worker)
      @fake_instance_1 = fake_instance
      @fake_instance_2 = fake_instance

      allow(@worker).to receive(:instances).and_return([@fake_instance_1, @fake_instance_2])
      allow(@fake_instance_1).to receive(:healthy?).and_return(true)
      allow(@fake_instance_2).to receive(:healthy?).and_return(false)
      allow(Container).to receive(:restart)
    end

    it 'restarts all containers' do
      @worker.restart!
      expect(Container).to have_received(:restart).twice
    end

    it 'can restart healthy containers' do
      @worker.restart!(healthy: true)
      expect(Container).to have_received(:restart).once
    end

    it 'can restart failing containers' do
      @worker.restart!(healthy: false)
      expect(Container).to have_received(:restart).once
    end
  end
end
